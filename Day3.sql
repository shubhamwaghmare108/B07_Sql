-- ===================================================================
--                      DAY 3: ADVANCED OBJECTS
--      Views | Stored Procedures | Functions | Triggers | Events
-- ===================================================================

-- ===================================================================
-- SECTION 1: SETUP (Test Database & Tables)
-- ===================================================================

DROP DATABASE IF EXISTS demo_objects;
CREATE DATABASE demo_objects;
USE demo_objects;

-- Create base tables for all demos
CREATE TABLE employees (
    emp_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary DECIMAL(10,2),
    hire_date DATE,
    is_active BOOLEAN DEFAULT TRUE
);

CREATE TABLE departments (
    dept_id INT PRIMARY KEY AUTO_INCREMENT,
    dept_name VARCHAR(50) UNIQUE,
    budget DECIMAL(15,2)
);

CREATE TABLE salary_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    emp_id INT,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (emp_id) REFERENCES employees(emp_id) ON DELETE CASCADE
);

-- Insert sample data
INSERT INTO departments (dept_name, budget) VALUES 
('Engineering', 500000),
('Sales', 300000),
('HR', 150000);

INSERT INTO employees (first_name, last_name, department, salary, hire_date) VALUES
('John', 'Doe', 'Engineering', 75000, '2020-01-15'),
('Jane', 'Smith', 'Engineering', 82000, '2019-06-20'),
('Bob', 'Johnson', 'Sales', 58000, '2021-03-10'),
('Alice', 'Williams', 'HR', 52000, '2022-07-01'),
('Charlie', 'Brown', 'Sales', 62000, '2020-11-05');

SELECT * FROM employees;
SELECT * FROM departments;
SELECT * FROM salary_history;


-- ===================================================================
-- SECTION 2: VIEWS (All Variations)
-- ===================================================================

-- [VARIATION 1] Simple View (Single table, subset of columns)
CREATE VIEW v_active_employees AS
SELECT emp_id, first_name, last_name, department, salary
FROM employees
WHERE is_active = TRUE;

-- [VARIATION 2] View with aliases
CREATE VIEW v_emp_names AS
SELECT emp_id, CONCAT(first_name, ' ', last_name) AS full_name, department
FROM employees;

-- [VARIATION 3] Complex View (JOIN across multiple tables)
CREATE VIEW v_employee_dept AS
SELECT e.emp_id, e.first_name, e.last_name, e.salary, 
       d.dept_name, d.budget
FROM employees e
INNER JOIN departments d ON e.department = d.dept_name;

-- [VARIATION 4] View with Aggregate (GROUP BY) - Non-updatable
CREATE VIEW v_dept_stats AS
SELECT department, 
       COUNT(*) AS emp_count, 
       AVG(salary) AS avg_salary,
       MAX(salary) AS max_salary,
       MIN(salary) AS min_salary
FROM employees
GROUP BY department;

-- [VARIATION 5] View with CHECK OPTION (Prevents inserts/updates that would hide the row)
CREATE VIEW v_engineering_emps AS
SELECT emp_id, first_name, last_name, salary
FROM employees
WHERE department = 'Engineering'
WITH CHECK OPTION;  -- Ensures new rows/updates keep department = 'Engineering'

-- [VARIATION 6] View with CASCADED CHECK OPTION (For views built on other views)
CREATE VIEW v_high_paid_eng AS
SELECT emp_id, first_name, last_name, salary
FROM v_engineering_emps
WHERE salary > 70000
WITH CASCADED CHECK OPTION;

-- [VARIATION 7] View with LOCAL CHECK OPTION (Checks only this view's condition)
CREATE VIEW v_sales_emps AS
SELECT emp_id, first_name, last_name, salary
FROM employees
WHERE department = 'Sales'
WITH LOCAL CHECK OPTION;  -- Only checks 'department = Sales'

-- [VARIATION 8] ALTER VIEW (Changing definition)
ALTER VIEW v_active_employees AS
SELECT emp_id, first_name, last_name, department, salary, hire_date
FROM employees
WHERE is_active = TRUE;

-- [VARIATION 9] Show View Definition
SHOW CREATE VIEW v_employee_dept;

-- [VARIATION 10] Rename View (using RENAME TABLE)
RENAME TABLE v_active_employees TO v_active_staff;

-- [VARIATION 11] DROP VIEW with IF EXISTS
DROP VIEW IF EXISTS v_emp_names;

-- [VARIATION 12] Updatable View Test (Insert/Update on simple view)
INSERT INTO v_engineering_emps (first_name, last_name, salary) 
VALUES ('Test', 'User', 60000);  -- Works, department defaults to 'Engineering' via check

SELECT * FROM employees WHERE first_name = 'Test';  -- Verify

-- [VARIATION 13] Try inserting into non-updatable view (should error or fail)
-- INSERT INTO v_dept_stats (department, emp_count) VALUES ('IT', 5); -- Error (aggregate)

-- [VARIATION 14] WITH READ ONLY (MySQL doesn't have explicit READ ONLY, but we can use options)
-- Note: MySQL allows updates on simple views. To prevent updates, we can use a trick:
-- CREATE VIEW v_readonly AS SELECT ... FROM ... (but users need privileges to restrict).


-- ===================================================================
-- SECTION 3: STORED PROCEDURES (All Variations)
-- =================================================================--

-- [VARIATION 1] Basic procedure (No parameters)
DELIMITER //

CREATE PROCEDURE sp_get_all_employees()
BEGIN
    SELECT * FROM employees;
END //

-- [VARIATION 2] Procedure with IN parameter
CREATE PROCEDURE sp_get_employee_by_dept(IN dept_name VARCHAR(50))
BEGIN
    SELECT emp_id, first_name, last_name, salary 
    FROM employees 
    WHERE department = dept_name;
END //

-- [VARIATION 3] Procedure with OUT parameter (return a value)
CREATE PROCEDURE sp_get_emp_count_by_dept(
    IN dept_name VARCHAR(50), 
    OUT emp_count INT
)
BEGIN
    SELECT COUNT(*) INTO emp_count
    FROM employees
    WHERE department = dept_name;
END //

-- [VARIATION 4] Procedure with INOUT parameter (read and modify)
CREATE PROCEDURE sp_apply_bonus(
    INOUT emp_id INT, 
    IN bonus_percent DECIMAL(5,2)
)
BEGIN
    DECLARE current_salary DECIMAL(10,2);
    
    SELECT salary INTO current_salary 
    FROM employees 
    WHERE emp_id = emp_id;
    
    UPDATE employees 
    SET salary = salary * (1 + bonus_percent/100) 
    WHERE emp_id = emp_id;
    
    -- Return the updated ID (just for demo, could be new ID if AUTO_INCREMENT)
    -- We keep emp_id as the same.
END //

-- [VARIATION 5] Procedure with Variables & Conditional (IF)
CREATE PROCEDURE sp_update_salary_with_check(
    IN p_emp_id INT,
    IN p_new_salary DECIMAL(10,2)
)
BEGIN
    DECLARE v_current_salary DECIMAL(10,2);
    DECLARE v_dept VARCHAR(50);
    DECLARE v_max_budget DECIMAL(15,2);
    
    -- Get current salary and department
    SELECT salary, department INTO v_current_salary, v_dept
    FROM employees WHERE emp_id = p_emp_id;
    
    -- Check if the new salary exceeds department budget
    SELECT budget INTO v_max_budget
    FROM departments WHERE dept_name = v_dept;
    
    IF p_new_salary > v_max_budget THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Salary exceeds department budget!';
    ELSE
        INSERT INTO salary_history (emp_id, old_salary, new_salary)
        VALUES (p_emp_id, v_current_salary, p_new_salary);
        
        UPDATE employees SET salary = p_new_salary WHERE emp_id = p_emp_id;
    END IF;
END //

-- [VARIATION 6] Procedure with CASE statement
CREATE PROCEDURE sp_get_grade(IN p_emp_id INT, OUT p_grade VARCHAR(10))
BEGIN
    DECLARE v_salary DECIMAL(10,2);
    
    SELECT salary INTO v_salary FROM employees WHERE emp_id = p_emp_id;
    
    CASE 
        WHEN v_salary >= 80000 THEN SET p_grade = 'A';
        WHEN v_salary >= 60000 THEN SET p_grade = 'B';
        WHEN v_salary >= 40000 THEN SET p_grade = 'C';
        ELSE SET p_grade = 'D';
    END CASE;
END //

-- [VARIATION 7] Procedure with LOOP (Infinite loop with LEAVE)
CREATE PROCEDURE sp_generate_employees(IN p_count INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    loop_label: LOOP
        IF i > p_count THEN
            LEAVE loop_label;
        END IF;
        
        INSERT INTO employees (first_name, last_name, department, salary, hire_date)
        VALUES (CONCAT('Gen', i), CONCAT('User', i), 'Engineering', 50000 + i*100, CURDATE());
        
        SET i = i + 1;
    END LOOP;
END //

-- [VARIATION 8] Procedure with WHILE loop
CREATE PROCEDURE sp_generate_emps_while(IN p_count INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    
    WHILE i <= p_count DO
        INSERT INTO employees (first_name, last_name, department, salary, hire_date)
        VALUES (CONCAT('While', i), CONCAT('User', i), 'HR', 40000 + i*200, CURDATE());
        SET i = i + 1;
    END WHILE;
END //

-- [VARIATION 9] Procedure with REPEAT loop
CREATE PROCEDURE sp_generate_emps_repeat(IN p_count INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    
    REPEAT
        INSERT INTO employees (first_name, last_name, department, salary, hire_date)
        VALUES (CONCAT('Repeat', i), CONCAT('User', i), 'Sales', 45000 + i*150, CURDATE());
        SET i = i + 1;
    UNTIL i > p_count
    END REPEAT;
END //

-- [VARIATION 10] Procedure with CURSOR (Iterate over result set)
CREATE PROCEDURE sp_apply_bonus_to_dept(
    IN p_dept VARCHAR(50),
    IN p_percent DECIMAL(5,2)
)
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE v_emp_id INT;
    DECLARE v_salary DECIMAL(10,2);
    
    -- Cursor declaration
    DECLARE emp_cursor CURSOR FOR 
        SELECT emp_id, salary FROM employees WHERE department = p_dept;
    
    -- Handler for NOT FOUND
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN emp_cursor;
    
    read_loop: LOOP
        FETCH emp_cursor INTO v_emp_id, v_salary;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Update salary with bonus
        UPDATE employees 
        SET salary = salary * (1 + p_percent/100) 
        WHERE emp_id = v_emp_id;
        
        -- Log the change
        INSERT INTO salary_history (emp_id, old_salary, new_salary)
        VALUES (v_emp_id, v_salary, salary * (1 + p_percent/100));
    END LOOP;
    
    CLOSE emp_cursor;
END //

-- [VARIATION 11] Procedure with Transaction Handling
CREATE PROCEDURE sp_transfer_employee(
    IN p_emp_id INT,
    IN p_new_dept VARCHAR(50)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
        UPDATE employees SET department = p_new_dept WHERE emp_id = p_emp_id;
        -- Simulate an error (e.g., foreign key violation if dept doesn't exist)
        -- Just checking if the new dept exists implicitly via the table.
    COMMIT;
END //

-- [VARIATION 12] DROP PROCEDURE
-- DROP PROCEDURE IF EXISTS sp_get_all_employees;

DELIMITER ;

-- [VARIATION 13] Calling Procedures (Demonstration)
CALL sp_get_all_employees();
CALL sp_get_employee_by_dept('Engineering');

SET @count = 0;
CALL sp_get_emp_count_by_dept('Sales', @count);
SELECT @count AS sales_emp_count;

SET @emp_id = 1;
CALL sp_apply_bonus(@emp_id, 10.0);  -- Gives 10% bonus to employee ID 1
SELECT * FROM employees WHERE emp_id = 1;

-- [VARIATION 14] CALL with OUT parameter using variable
CALL sp_get_grade(1, @grade);
SELECT @grade AS emp_grade;


-- ===================================================================
-- SECTION 4: STORED FUNCTIONS (All Variations)
-- ===================================================================

DELIMITER //

-- [VARIATION 1] Simple function (returns a scalar value)
CREATE FUNCTION fn_get_full_name(p_emp_id INT) 
RETURNS VARCHAR(100)
DETERMINISTIC  -- Always returns the same for same input (if data doesn't change)
READS SQL DATA  -- Only reads, no writes
BEGIN
    DECLARE full_name VARCHAR(100);
    
    SELECT CONCAT(first_name, ' ', last_name) INTO full_name
    FROM employees WHERE emp_id = p_emp_id;
    
    RETURN full_name;
END //

-- [VARIATION 2] Function with parameters and calculations
CREATE FUNCTION fn_calc_tax(p_salary DECIMAL(10,2)) 
RETURNS DECIMAL(10,2)
DETERMINISTIC
NO SQL  -- Doesn't access tables
BEGIN
    DECLARE tax DECIMAL(10,2);
    SET tax = p_salary * 0.20;  -- 20% tax
    RETURN tax;
END //

-- [VARIATION 3] Function reading from multiple tables
CREATE FUNCTION fn_get_dept_budget_utilization(p_dept VARCHAR(50)) 
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE total_salary DECIMAL(15,2);
    DECLARE dept_budget DECIMAL(15,2);
    DECLARE utilization DECIMAL(5,2);
    
    SELECT SUM(salary) INTO total_salary 
    FROM employees WHERE department = p_dept;
    
    SELECT budget INTO dept_budget 
    FROM departments WHERE dept_name = p_dept;
    
    IF dept_budget = 0 THEN
        RETURN 0;
    END IF;
    
    SET utilization = (total_salary / dept_budget) * 100;
    RETURN utilization;
END //

-- [VARIATION 4] Function using IF/CASE
CREATE FUNCTION fn_get_employment_status(p_hire_date DATE) 
RETURNS VARCHAR(20)
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE years_diff INT;
    SET years_diff = TIMESTAMPDIFF(YEAR, p_hire_date, CURDATE());
    
    IF years_diff < 1 THEN
        RETURN 'New';
    ELSEIF years_diff < 3 THEN
        RETURN 'Junior';
    ELSEIF years_diff < 5 THEN
        RETURN 'Senior';
    ELSE
        RETURN 'Veteran';
    END IF;
END //

-- [VARIATION 5] Function with HANDLER for errors (e.g., no data found)
CREATE FUNCTION fn_get_salary_safely(p_emp_id INT) 
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_salary DECIMAL(10,2) DEFAULT 0;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_salary = -1;
    
    SELECT salary INTO v_salary FROM employees WHERE emp_id = p_emp_id;
    RETURN v_salary;
END //

-- [VARIATION 6] DROP FUNCTION
-- DROP FUNCTION IF EXISTS fn_get_full_name;

DELIMITER ;

-- [VARIATION 7] Calling Functions (SELECT usage)
SELECT emp_id, 
       fn_get_full_name(emp_id) AS full_name,
       salary,
       fn_calc_tax(salary) AS tax,
       fn_get_employment_status(hire_date) AS tenure_status
FROM employees;

-- Using function in a WHERE clause
SELECT * FROM employees 
WHERE fn_get_employment_status(hire_date) = 'Veteran';

-- Calling standalone function
SELECT fn_get_dept_budget_utilization('Engineering') AS budget_util;


-- ===================================================================
-- SECTION 5: TRIGGERS (All Variations - BEFORE/AFTER, INSERT/UPDATE/DELETE)
-- ===================================================================

DELIMITER //

-- [VARIATION 1] BEFORE INSERT Trigger (Validate data before insert)
CREATE TRIGGER trg_before_insert_employee
BEFORE INSERT ON employees
FOR EACH ROW
BEGIN
    -- Ensure salary is not negative
    IF NEW.salary < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Salary cannot be negative!';
    END IF;
    
    -- Set default hire_date to today if null
    IF NEW.hire_date IS NULL THEN
        SET NEW.hire_date = CURDATE();
    END IF;
END //

-- [VARIATION 2] AFTER INSERT Trigger (Log the insertion)
CREATE TRIGGER trg_after_insert_employee
AFTER INSERT ON employees
FOR EACH ROW
BEGIN
    INSERT INTO salary_history (emp_id, old_salary, new_salary, change_date)
    VALUES (NEW.emp_id, 0, NEW.salary, NOW());
END //

-- [VARIATION 3] BEFORE UPDATE Trigger (Log old values before update)
CREATE TRIGGER trg_before_update_employee
BEFORE UPDATE ON employees
FOR EACH ROW
BEGIN
    -- Prevent updating to a negative salary
    IF NEW.salary < 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot update to negative salary!';
    END IF;
    
    -- Optionally track changes in a separate log (we have AFTER UPDATE too)
END //

-- [VARIATION 4] AFTER UPDATE Trigger (Log changes to salary_history)
CREATE TRIGGER trg_after_update_employee
AFTER UPDATE ON employees
FOR EACH ROW
BEGIN
    -- Only log if salary changed
    IF OLD.salary != NEW.salary THEN
        INSERT INTO salary_history (emp_id, old_salary, new_salary, change_date)
        VALUES (NEW.emp_id, OLD.salary, NEW.salary, NOW());
    END IF;
END //

-- [VARIATION 5] BEFORE DELETE Trigger (Prevent deleting active employees)
CREATE TRIGGER trg_before_delete_employee
BEFORE DELETE ON employees
FOR EACH ROW
BEGIN
    IF OLD.is_active = TRUE THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Cannot delete an active employee. Deactivate first!';
    END IF;
END //

-- [VARIATION 6] AFTER DELETE Trigger (Clean up logs, or archive data)
CREATE TRIGGER trg_after_delete_employee
AFTER DELETE ON employees
FOR EACH ROW
BEGIN
    -- Insert into an archive table (if existed)
    -- INSERT INTO employees_archive (emp_id, first_name, ...) VALUES (OLD.emp_id, ...);
    -- For now, just log the deletion in the history table.
    INSERT INTO salary_history (emp_id, old_salary, new_salary, change_date)
    VALUES (OLD.emp_id, OLD.salary, 0, NOW());
END //

-- [VARIATION 7] Show all triggers
-- SHOW TRIGGERS;

-- [VARIATION 8] DROP Trigger
-- DROP TRIGGER IF EXISTS trg_before_insert_employee;

DELIMITER ;

-- Testing Triggers
-- Insert a valid employee
INSERT INTO employees (first_name, last_name, department, salary, hire_date) 
VALUES ('Trigger', 'Test', 'Engineering', 50000, NULL);  -- hire_date will be set by trigger

-- Insert with negative salary (Should fail due to BEFORE INSERT trigger)
-- INSERT INTO employees (first_name, last_name, department, salary) 
-- VALUES ('Bad', 'Data', 'Engineering', -1000);  -- Will raise an error

-- Update salary (should log to salary_history)
UPDATE employees SET salary = 55000 WHERE emp_id = 6;  -- Assuming ID 6 exists from insert
SELECT * FROM salary_history WHERE emp_id = 6;

-- Delete test (will fail if is_active = TRUE)
-- UPDATE employees SET is_active = FALSE WHERE emp_id = 6;  -- Deactivate first
-- DELETE FROM employees WHERE emp_id = 6;  -- Now it works


-- ===================================================================
-- SECTION 6: EVENTS (Scheduled Jobs - All Variations)
-- ===================================================================

-- [VARIATION 1] Check if Event Scheduler is ON
SHOW VARIABLES LIKE 'event_scheduler';

-- [VARIATION 2] Turn ON Event Scheduler (requires admin privileges)
-- SET GLOBAL event_scheduler = ON;

-- [VARIATION 3] Create a one-time event (Executes once after a delay)
CREATE EVENT evt_one_time_cleanup
ON SCHEDULE AT (CURRENT_TIMESTAMP + INTERVAL 1 MINUTE)
DO
BEGIN
    -- Delete employees with 'Test' in first_name (for cleanup)
    DELETE FROM employees WHERE first_name LIKE 'Test%' AND is_active = FALSE;
END //

-- [VARIATION 4] Create a recurring event (Runs every day at midnight)
CREATE EVENT evt_daily_archive
ON SCHEDULE EVERY 1 DAY 
STARTS (CURRENT_TIMESTAMP + INTERVAL 1 DAY)
ENDS (CURRENT_TIMESTAMP + INTERVAL 1 MONTH)
DO
BEGIN
    -- Archive employees who resigned (is_active = FALSE) older than 30 days
    -- (Placeholder logic)
    -- DELETE FROM employees WHERE is_active = FALSE AND hire_date < CURDATE() - INTERVAL 30 DAY;
    -- For demo: Insert a log entry into a dummy archive table.
    INSERT INTO salary_history (emp_id, old_salary, new_salary)
    VALUES (0, 0, 0) ;  -- Dummy entry to show event ran
END //

-- [VARIATION 5] Create an event with a complex schedule (Every hour on weekdays)
CREATE EVENT evt_weekly_report
ON SCHEDULE EVERY 1 HOUR
STARTS (CURRENT_TIMESTAMP + INTERVAL 1 HOUR)
ENDS (CURRENT_TIMESTAMP + INTERVAL 1 YEAR)
DO
BEGIN
    -- Some reporting logic
    -- INSERT INTO reports (report_date, data) VALUES (NOW(), 'Some data');
    -- For demo: update a timestamp.
    -- This is just a placeholder.
    SELECT 'Event executed' INTO @dummy;
END //

-- [VARIATION 6] ALTER EVENT (Disable, Enable, or Change Schedule)
ALTER EVENT evt_daily_archive DISABLE;  -- Pause the event
ALTER EVENT evt_daily_archive ENABLE;   -- Resume
ALTER EVENT evt_daily_archive
ON SCHEDULE EVERY 2 DAY
STARTS (CURRENT_TIMESTAMP + INTERVAL 1 DAY);

-- [VARIATION 7] Show events
SHOW EVENTS FROM demo_objects;

-- [VARIATION 8] DROP EVENT
-- DROP EVENT IF EXISTS evt_one_time_cleanup;

-- [VARIATION 9] Execute an event manually (for testing)
-- CALL evt_daily_archive();  -- Doesn't work directly, but you can call the DO block logic in a procedure.

-- ===================================================================
-- SECTION 7: INFORMATION_SCHEMA QUERIES (Meta-data for all objects)
-- ===================================================================

-- View all views
SELECT TABLE_NAME, VIEW_DEFINITION 
FROM INFORMATION_SCHEMA.VIEWS 
WHERE TABLE_SCHEMA = 'demo_objects';

-- View all stored procedures
SELECT ROUTINE_NAME, ROUTINE_TYPE 
FROM INFORMATION_SCHEMA.ROUTINES 
WHERE ROUTINE_SCHEMA = 'demo_objects';

-- View all triggers
SELECT TRIGGER_NAME, EVENT_MANIPULATION, EVENT_OBJECT_TABLE
FROM INFORMATION_SCHEMA.TRIGGERS
WHERE TRIGGER_SCHEMA = 'demo_objects';

-- View all events
SELECT EVENT_NAME, STATUS, EVENT_TYPE, EXECUTE_AT, INTERVAL_VALUE, INTERVAL_FIELD
FROM INFORMATION_SCHEMA.EVENTS
WHERE EVENT_SCHEMA = 'demo_objects';


-- ===================================================================
-- SECTION 8: FINAL CLEANUP (Optional)
-- ===================================================================

-- DROP DATABASE IF EXISTS demo_objects;
-- SET GLOBAL event_scheduler = OFF; (if you turned it on)

-- ===================================================================
--                           SUMMARY OF COVERAGE
-- 
-- VIEWS:        Simple, Complex (JOIN), Aggregate, WITH CHECK OPTION 
--               (CASCADED/LOCAL), ALTER, RENAME, DROP, Show Definition.
-- 
-- PROCEDURES:   IN, OUT, INOUT params, IF/CASE, LOOP/WHILE/REPEAT, 
--               CURSOR, Transactions (COMMIT/ROLLBACK), Error Handling 
--               (DECLARE HANDLER), SIGNAL.
-- 
-- FUNCTIONS:    Deterministic/Non-deterministic, SQL Data Access 
--               (READS SQL DATA, NO SQL), IF/CASE, Error Handling, 
--               Scalar returns.
-- 
-- TRIGGERS:     BEFORE/AFTER on INSERT/UPDATE/DELETE, OLD/NEW references,
--               Conditional logic, SIGNAL for validation.
-- 
-- EVENTS:       One-time vs Recurring (EVERY, AT), STARTS/ENDS, 
--               ALTER (ENABLE/DISABLE), DROP, SHOW.
-- 
-- METADATA:     INFORMATION_SCHEMA queries for all object types.
-- ===================================================================