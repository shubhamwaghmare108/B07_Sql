-- ===================================================================
--                    COMPLETE COMBINED SQL SCRIPT
--            (Your Original Day1.sql + All Advanced Variations)
-- ===================================================================

-- ===================================================================
-- SECTION 1: DATABASE OPERATIONS (Original + New Variations)
-- ===================================================================

-- [NEW] Clean start: Drop database if exists (avoids duplicate errors)
DROP DATABASE IF EXISTS demo;

-- [ORIGINAL] Create database
CREATE DATABASE demo; -- how to create database

-- [ORIGINAL] Create database with IF NOT EXISTS
CREATE DATABASE IF NOT EXISTS demo; -- how to create database

-- [NEW VARIATION] Create database with specific character set and collation
CREATE DATABASE IF NOT EXISTS demo_utf8 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

-- [ORIGINAL] List all databases
SHOW DATABASES; -- list of database

-- [NEW VARIATION] Show the CREATE SQL for a database
SHOW CREATE DATABASE demo;

-- [NEW VARIATION] Alter database properties
ALTER DATABASE demo_utf8 CHARACTER SET latin1;

-- [NEW VARIATION] Drop database safely
DROP DATABASE IF EXISTS demo_utf8;

-- [ORIGINAL] Use the database
USE demo;
-- [FIX] Changed from 'DEMO' to 'demo' for case-consistency (MySQL on Linux is case-sensitive)

-- [ORIGINAL] Show current database
/* sdffghjgdfjkg
sadfghjsdhfj
afsdghjsvdbfn
*/ -- multiline comment
-- show the currunt database
SELECT DATABASE();


-- ===================================================================
-- SECTION 2: TABLE CREATION (Original + Advanced Constraints)
-- ===================================================================

-- [ORIGINAL] Create basic STUDENTS table
CREATE TABLE STUDENTS
(id int,
`name` char(20),
mob_num char(10)
);

-- [ORIGINAL] Show tables and describe
SHOW TABLES;
DESCRIBE students;

-- [NEW VARIATION] Create an advanced table with PRIMARY KEY, AUTO_INCREMENT,
-- UNIQUE, DEFAULT, and CHECK constraints (MySQL 8.0+)
CREATE TABLE students_adv (
    id INT PRIMARY KEY AUTO_INCREMENT,          -- Auto-incrementing PK
    stu_name VARCHAR(50) NOT NULL DEFAULT 'Guest', -- NOT NULL with DEFAULT
    mob_num CHAR(10) UNIQUE,                    -- Unique constraint
    city VARCHAR(20) DEFAULT 'Mumbai',
    age INT CHECK (age >= 18)                   -- Check constraint
);

-- [NEW VARIATION] Show the detailed structure of the advanced table
DESCRIBE students_adv;
SHOW CREATE TABLE students_adv;


-- ===================================================================
-- SECTION 3: ALTER TABLE VARIATIONS (Original + Advanced)
-- ===================================================================

-- [ORIGINAL] Rename column using RENAME COLUMN
ALTER TABLE students
RENAME COLUMN `name` TO stu_name;

-- [ORIGINAL] Verify the change
SELECT * FROM students;
DESC students;

-- [NEW VARIATION] ALTER TABLE ... CHANGE COLUMN (Renames AND changes datatype in one go)
ALTER TABLE students_adv 
CHANGE COLUMN stu_name student_name VARCHAR(30); -- Changed name + type

-- [NEW VARIATION] Multiple ALTER operations in a single statement
ALTER TABLE students_adv 
ADD COLUMN joining_date DATE DEFAULT (CURDATE()),
MODIFY COLUMN mob_num VARCHAR(15),
DROP COLUMN city;

-- [NEW VARIATION] Add / Drop constraints explicitly
ALTER TABLE students_adv ADD PRIMARY KEY (id);    -- (Already has it, but shown)
ALTER TABLE students_adv ADD INDEX idx_name (student_name); -- Add index
ALTER TABLE students_adv DROP INDEX idx_name;                -- Drop index

-- [NEW VARIATION] Set / Drop DEFAULT value
ALTER TABLE students_adv ALTER COLUMN age SET DEFAULT 25;
ALTER TABLE students_adv ALTER COLUMN age DROP DEFAULT;

-- Verify the advanced table structure
DESC students_adv;


-- ===================================================================
-- SECTION 4: INSERT VARIATIONS (Original + Advanced)
-- ===================================================================

-- [ORIGINAL] Positional INSERT (single row)
INSERT INTO students VALUES (1,'shubham','1234671389');
SELECT * FROM students;

-- [ORIGINAL] Positional INSERT (multiple rows)
INSERT INTO students VALUES
(2,'shubham','1456671389'),
(3,'raj','75821682'),
(4,'nikita','7896543321');
SELECT * FROM students;

-- [ORIGINAL] INSERT with column specification (Keyword style)
INSERT INTO students(id,stu_name) VALUES (5,'shubham');
SELECT * FROM students;

-- [ORIGINAL] ALTER to change column size to accept larger data
ALTER TABLE students MODIFY COLUMN mob_num CHAR(30);
INSERT INTO students VALUES (6,'ravi','789456123123456789');
SELECT * FROM students;

-- [ORIGINAL] ADD / MODIFY / DROP column (just to show flow)
ALTER TABLE students ADD COLUMN city CHAR(20) AFTER stu_name;
ALTER TABLE students MODIFY COLUMN mob_num CHAR(30) AFTER stu_name;
ALTER TABLE students MODIFY COLUMN city CHAR(20) FIRST;
SELECT * FROM students;
ALTER TABLE students DROP COLUMN city;

-- ================ [NEW INSERT VARIATIONS] ================

-- [NEW] INSERT ... SET syntax (alternative to VALUES)
INSERT INTO students_adv SET id = 10, student_name = 'Amit', mob_num = '9876543210', age = 25;
SELECT * FROM students_adv;

-- [NEW] INSERT IGNORE (skips rows that cause duplicate key errors)
INSERT IGNORE INTO students_adv (id, student_name, mob_num) VALUES 
(10, 'Duplicate', '1111111111'),  -- ID 10 already exists -> skipped
(11, 'Neha', '2222222222');       -- New row -> inserted
SELECT * FROM students_adv;

-- [NEW] REPLACE INTO (If PK/Unique exists, deletes old and inserts new)
REPLACE INTO students_adv (id, student_name, mob_num) VALUES (10, 'Replaced_Amit', '9999999999');
SELECT * FROM students_adv;

-- [NEW] INSERT ... ON DUPLICATE KEY UPDATE (Update if exists, insert if not)
INSERT INTO students_adv (id, student_name, mob_num, age) 
VALUES (10, 'Updated_Again', '8888888888', 30) 
ON DUPLICATE KEY UPDATE 
    student_name = 'Updated_Again', 
    mob_num = '8888888888', 
    age = 30;
SELECT * FROM students_adv;


-- ===================================================================
-- SECTION 5: SELECT QUERY VARIATIONS (ALL NEW)
-- ===================================================================

-- Insert a few more rows into students_adv for demo purposes
INSERT INTO students_adv (student_name, mob_num, age) VALUES 
('Rohan', '3333333333', 22),
('Priya', '4444444444', 19),
('Vikram', '5555555555', 35),
('Anjali', '6666666666', 28);

-- [NEW] SELECT DISTINCT (remove duplicates)
SELECT DISTINCT student_name FROM students_adv;

-- [NEW] SELECT with WHERE conditions
SELECT * FROM students_adv WHERE id > 12;
SELECT * FROM students_adv WHERE age >= 25;
SELECT * FROM students_adv WHERE student_name LIKE 'R%';   -- Starts with 'R'
SELECT * FROM students_adv WHERE student_name LIKE '%a';    -- Ends with 'a'
SELECT * FROM students_adv WHERE id IN (10, 11, 15);       -- Using IN

-- [NEW] SELECT with ORDER BY (Sorting)
SELECT * FROM students_adv ORDER BY age ASC;   -- Youngest first
SELECT * FROM students_adv ORDER BY student_name DESC, id ASC; -- Desc name, then asc id

-- [NEW] SELECT with LIMIT and OFFSET (Pagination)
SELECT * FROM students_adv LIMIT 2;          -- First 2 rows
SELECT * FROM students_adv LIMIT 2 OFFSET 2; -- Skip 2, take next 2

-- [NEW] SELECT with Column & Table Aliases
SELECT s.id AS StudentID, s.student_name AS Name FROM students_adv AS s;


-- ===================================================================
-- SECTION 6: UPDATE / DELETE VARIATIONS (Original + Advanced)
-- ===================================================================

-- [ORIGINAL] UPDATE and DELETE setup
SET sql_safe_updates = 0;  -- Allows updates without WHERE clause (Original)

-- [ORIGINAL] UPDATE with WHERE
UPDATE students
SET mob_num ='466+78225'
WHERE id = 5;

-- [ORIGINAL] DELETE with WHERE
DELETE FROM students
WHERE id = 6;

SELECT * FROM students;  -- Final state of original table

-- ================ [NEW UPDATE / DELETE VARIATIONS] ================

-- [NEW] UPDATE multiple columns at once
UPDATE students_adv 
SET student_name = 'ROHAN_K', age = 23 
WHERE id = 14;

-- [NEW] UPDATE with ORDER BY and LIMIT (update top N rows)
UPDATE students_adv 
SET age = 99 
ORDER BY id DESC 
LIMIT 1;  -- Updates the most recently added row (highest ID)

-- [NEW] DELETE with ORDER BY and LIMIT (delete specific top N rows)
DELETE FROM students_adv 
ORDER BY id ASC 
LIMIT 1;  -- Deletes the smallest ID (currently ID 10)

-- [NEW] DELETE with WHERE condition
DELETE FROM students_adv WHERE age > 30;

-- Check final state of advanced table
SELECT * FROM students_adv;


-- ===================================================================
-- SECTION 7: TABLE CLONING & COPYING (Original + Advanced)
-- ===================================================================

-- [ORIGINAL] Clone structure only (LIKE)
CREATE TABLE students_copy LIKE students;
SELECT * FROM students_copy;  -- Empty

-- [ORIGINAL] Insert data into cloned table
INSERT INTO students_copy SELECT * FROM students;

-- [ORIGINAL] Drop table
DROP TABLE students_copy;

-- [ORIGINAL] Clone structure + data (CREATE AS SELECT)
CREATE TABLE students_copy SELECT * FROM students;
SELECT * FROM students_copy;

-- [ORIGINAL] Rename table
RENAME TABLE students_copy TO copy;
SHOW TABLES;

-- [ORIGINAL] Truncate table
TRUNCATE TABLE copy;
SELECT * FROM copy;  -- Empty

-- ================ [NEW CLONING VARIATIONS] ================

-- [NEW] Clone only specific columns and data
CREATE TABLE students_backup AS SELECT id, stu_name, mob_num FROM students;
SELECT * FROM students_backup;

-- [NEW] Clone with a WHERE condition (partial data)
CREATE TABLE students_filtered AS SELECT * FROM students WHERE id < 4;
SELECT * FROM students_filtered;  -- Only IDs 1,2,3

-- [NEW] Clone structure only (alternative to LIKE using WHERE 1=0)
CREATE TABLE students_empty AS SELECT * FROM students WHERE 1=0;
SELECT * FROM students_empty;  -- Empty, but has structure


-- ===================================================================
-- SECTION 8: TRANSACTIONS (ALL NEW)
-- ===================================================================

-- Insert test data for transaction demo
CREATE TABLE employees (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_name VARCHAR(50),
    salary INT
);

INSERT INTO employees (emp_name, salary) VALUES 
('Alice', 50000),
('Bob', 60000),
('Charlie', 70000);

-- [NEW] START TRANSACTION with COMMIT and ROLLBACK
START TRANSACTION;
    UPDATE employees SET salary = salary + 5000 WHERE emp_id = 1;
    DELETE FROM employees WHERE emp_id = 3;
    SELECT * FROM employees;  -- Shows changes (Alice: 55000, Bob: 60000)
ROLLBACK;  -- Undo everything

SELECT * FROM employees;  -- Back to original (Alice: 50000, Bob: 60000, Charlie: 70000)

-- [NEW] Using SAVEPOINT for partial rollback
START TRANSACTION;
    UPDATE employees SET salary = 99999 WHERE emp_id = 1;
    SAVEPOINT sp1;
    DELETE FROM employees WHERE emp_id = 2;
    SELECT * FROM employees;  -- Alice: 99999, Bob gone
    
    ROLLBACK TO SAVEPOINT sp1;  -- Undo only the DELETE (Bob comes back)
    SELECT * FROM employees;  -- Alice: 99999, Bob: 60000, Charlie: 70000
    
COMMIT;  -- Permanently save (Alice remains 99999)
SELECT * FROM employees;


-- ===================================================================
-- SECTION 9: METADATA & DIAGNOSTIC COMMANDS (ALL NEW)
-- ===================================================================

-- [NEW] SHOW FULL TABLES (shows BASE TABLE or VIEW)
SHOW FULL TABLES IN demo;

-- [NEW] SHOW TABLES with LIKE pattern
SHOW TABLES LIKE '%student%';

-- [NEW] DESCRIBE / EXPLAIN alternatives
DESCRIBE students;    -- Original
EXPLAIN students;     -- Synonym for DESCRIBE
SHOW COLUMNS FROM students;
SHOW FULL COLUMNS FROM students;  -- Shows collation, privileges, comments

-- [NEW] SHOW INDEX (see all indexes and keys)
SHOW INDEX FROM students_adv;

-- [NEW] SHOW WARNINGS (after an insert that causes a warning)
-- Example: Insert a NULL into a NOT NULL column (if applicable)
INSERT INTO students_adv (id, mob_num) VALUES (99, '0000000000'); 
-- (will fail if student_name is NOT NULL, or succeed if default applies)
SHOW WARNINGS;

-- [NEW] SET FOREIGN_KEY_CHECKS (to bypass constraints temporarily)
SET FOREIGN_KEY_CHECKS = 0;
-- (You can now TRUNCATE / DROP parent tables without errors)
SET FOREIGN_KEY_CHECKS = 1;

-- ===================================================================
-- FINAL CLEANUP (Optional - comment out if you want to keep data)
-- ===================================================================
-- DROP TABLE IF EXISTS students, students_adv, students_backup, students_filtered, students_empty, employees, copy;
-- DROP DATABASE IF EXISTS demo;
-- ===================================================================