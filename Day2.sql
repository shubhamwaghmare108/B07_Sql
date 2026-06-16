-- ===================================================================
--                      DAY 2: TCL + DCL
--        Complete Guide to Transactions, Locks, Users & Permissions
-- ===================================================================

-- ===================================================================
-- SECTION 1: SETUP (Test Database & Tables for TCL Demos)
-- ===================================================================

-- Clean up previous test data (if any)
DROP DATABASE IF EXISTS demo_tcl_dcl;
CREATE DATABASE demo_tcl_dcl;
USE demo_tcl_dcl;

-- Create a sample 'accounts' table for transaction demonstrations
CREATE TABLE accounts (
    acc_id INT PRIMARY KEY AUTO_INCREMENT,
    acc_holder VARCHAR(50),
    balance DECIMAL(10, 2) DEFAULT 0.00
);

-- Create a 'logs' table to show transaction effects
CREATE TABLE transaction_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    acc_id INT,
    action VARCHAR(20),
    amount DECIMAL(10, 2),
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert initial data
INSERT INTO accounts (acc_holder, balance) VALUES 
('Alice', 1000.00),
('Bob', 500.00),
('Charlie', 200.00);

SELECT * FROM accounts;


-- ===================================================================
-- SECTION 2: TCL - AUTOCOMMIT VARIATIONS
-- ===================================================================

-- [VARIATION 1] Check current autocommit status
SELECT @@autocommit;  -- 1 means ON (default), 0 means OFF

-- [VARIATION 2] Disable autocommit for the current session
SET autocommit = 0;
SELECT @@autocommit;  -- Now 0

-- Perform an update (will NOT be permanent until COMMIT)
UPDATE accounts SET balance = balance - 100 WHERE acc_id = 1;
SELECT * FROM accounts;  -- Alice now 900 (in memory only)

-- Rollback to undo the change (since autocommit is OFF)
ROLLBACK;
SELECT * FROM accounts;  -- Alice is back to 1000

-- [VARIATION 3] Re-enable autocommit
SET autocommit = 1;
SELECT @@autocommit;


-- ===================================================================
-- SECTION 3: TCL - BASIC TRANSACTIONS (START, COMMIT, ROLLBACK)
-- ===================================================================

-- [SCENARIO] Transfer $200 from Alice (acc_id=1) to Bob (acc_id=2)
START TRANSACTION;  -- Explicitly starts a transaction

    -- Deduct from Alice
    UPDATE accounts SET balance = balance - 200 WHERE acc_id = 1;
    
    -- Add to Bob
    UPDATE accounts SET balance = balance + 200 WHERE acc_id = 2;
    
    -- Check intermediate state (only visible to this session)
    SELECT * FROM accounts;  -- Alice: 800, Bob: 700

-- [VARIATION 1] COMMIT (makes changes permanent)
COMMIT;
SELECT * FROM accounts;  -- Changes are now permanent for all sessions

-- [SCENARIO] Another transfer, but we decide to cancel it
START TRANSACTION;
    UPDATE accounts SET balance = balance - 300 WHERE acc_id = 1;  -- Alice: 500
    UPDATE accounts SET balance = balance + 300 WHERE acc_id = 3;  -- Charlie: 500

-- [VARIATION 2] ROLLBACK (aborts all changes in the transaction)
ROLLBACK;
SELECT * FROM accounts;  -- Alice back to 800, Charlie back to 200

-- [VARIATION 3] Using BEGIN as an alternative to START TRANSACTION
BEGIN;
    UPDATE accounts SET balance = balance + 50 WHERE acc_id = 2;  -- Bob: 750
COMMIT;  -- Save it permanently
SELECT * FROM accounts;


-- ===================================================================
-- SECTION 4: TCL - SAVEPOINTS (Partial Rollback)
-- ===================================================================

-- Reset data to baseline for clear demo
UPDATE accounts SET balance = 1000 WHERE acc_id = 1;
UPDATE accounts SET balance = 500 WHERE acc_id = 2;
UPDATE accounts SET balance = 200 WHERE acc_id = 3;
COMMIT;

START TRANSACTION;

    -- Step 1: Deduct from Alice
    UPDATE accounts SET balance = balance - 100 WHERE acc_id = 1;  -- Alice: 900
    SAVEPOINT sp1;  -- Mark this point
    
    -- Step 2: Add to Bob
    UPDATE accounts SET balance = balance + 100 WHERE acc_id = 2;  -- Bob: 600
    SAVEPOINT sp2;
    
    -- Step 3: Add to Charlie (Oops, we shouldn't have done this)
    UPDATE accounts SET balance = balance + 100 WHERE acc_id = 3;  -- Charlie: 300

    -- Check current state
    SELECT * FROM accounts;  -- Alice:900, Bob:600, Charlie:300

-- [VARIATION 1] Rollback to sp2 (undoes ONLY the Charlie update)
ROLLBACK TO SAVEPOINT sp2;
SELECT * FROM accounts;  -- Alice:900, Bob:600, Charlie:200 (Charlie undone)

-- [VARIATION 2] Rollback to sp1 (undoes Bob update too, Alice remains deducted)
ROLLBACK TO SAVEPOINT sp1;
SELECT * FROM accounts;  -- Alice:900, Bob:500, Charlie:200 (Bob undone)

-- [VARIATION 3] Release a savepoint (removes it without undoing changes)
RELEASE SAVEPOINT sp1;  -- sp1 is now gone

-- [VARIATION 4] Commit the remaining change (Alice stays at 900)
COMMIT;
SELECT * FROM accounts;  -- Alice:900, Bob:500, Charlie:200


-- ===================================================================
-- SECTION 5: TCL - TRANSACTION ISOLATION LEVELS (ALL 4 VARIATIONS)
-- ===================================================================

-- [VARIATION 1] READ UNCOMMITTED (Dirty reads allowed - lowest consistency)
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
START TRANSACTION;
    SELECT * FROM accounts;  -- Can see uncommitted changes from other sessions
COMMIT;

-- [VARIATION 2] READ COMMITTED (No dirty reads, but non-repeatable reads possible)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
START TRANSACTION;
    SELECT balance FROM accounts WHERE acc_id = 1;  -- Reads committed data only
COMMIT;

-- [VARIATION 3] REPEATABLE READ (Default for InnoDB - Consistent snapshot)
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
START TRANSACTION;
    SELECT balance FROM accounts WHERE acc_id = 1;  -- Same result throughout transaction
COMMIT;

-- [VARIATION 4] SERIALIZABLE (Strictest - forces lock-based concurrency)
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
START TRANSACTION;
    SELECT * FROM accounts;  -- Locks the table for other writes
COMMIT;

-- [VARIATION 5] View the current isolation level
SELECT @@transaction_isolation;  -- MySQL 8.0+ (or @@tx_isolation for older)


-- ===================================================================
-- SECTION 6: TCL - LOCKING READS (FOR UPDATE & LOCK IN SHARE MODE)
-- ===================================================================

-- Reset data
UPDATE accounts SET balance = 1000 WHERE acc_id = 1;
COMMIT;

-- [VARIATION 1] SELECT ... FOR UPDATE (Exclusive Row Lock)
START TRANSACTION;
    -- Locks Alice's row exclusively. Other sessions cannot update it until COMMIT.
    SELECT balance FROM accounts WHERE acc_id = 1 FOR UPDATE;
    
    -- Perform the actual update
    UPDATE accounts SET balance = balance - 50 WHERE acc_id = 1;
COMMIT;  -- Lock is released here

-- [VARIATION 2] SELECT ... LOCK IN SHARE MODE (Shared Lock)
START TRANSACTION;
    -- Locks Alice's row for reading. Other sessions can read, but cannot write.
    SELECT balance FROM accounts WHERE acc_id = 1 LOCK IN SHARE MODE;
    -- Simulate a read operation
COMMIT;  -- Shared lock released


-- ===================================================================
-- SECTION 7: TCL - TABLE LOCKS (Manual Locking)
-- ===================================================================

-- [VARIATION 1] LOCK TABLES (Write lock - exclusive)
LOCK TABLES accounts WRITE;
    -- Now this session can read/write, others cannot access the table
    UPDATE accounts SET balance = 999 WHERE acc_id = 1;
    SELECT * FROM accounts;
UNLOCK TABLES;  -- Release the lock

-- [VARIATION 2] LOCK TABLES (Read lock - shared)
LOCK TABLES accounts READ;
    -- This session can read, but cannot write.
    -- Other sessions can read, but cannot write.
    SELECT * FROM accounts;
UNLOCK TABLES;

-- [VARIATION 3] Lock multiple tables at once
LOCK TABLES accounts WRITE, transaction_logs WRITE;
    -- Perform operations on both tables
    INSERT INTO transaction_logs (acc_id, action, amount) VALUES (1, 'LOCK_TEST', 100);
UNLOCK TABLES;

SELECT * FROM transaction_logs;


-- ===================================================================
-- ===================================================================
--              SECTION 8: DCL - USER MANAGEMENT
--  (⚠️  Requires SUPER or CREATE USER privilege. Run as root/admin)
-- ===================================================================
-- ===================================================================

-- Switch to a privileged user (e.g., root) for the rest of this script.
-- Uncomment and execute the following lines if you are root.

-- [VARIATION 1] CREATE USER with specific host and password
-- CREATE USER IF NOT EXISTS 'demo_user'@'localhost' IDENTIFIED BY 'StrongPass123!';

-- [VARIATION 2] CREATE USER without password (MySQL 8+ requires password policy)
-- CREATE USER IF NOT EXISTS 'demo_user2'@'%' IDENTIFIED BY 'AnotherPass456!';

-- [VARIATION 3] ALTER USER (Change password, expire password, lock/unlock)
-- ALTER USER 'demo_user'@'localhost' IDENTIFIED BY 'NewSuperPass789!';
-- ALTER USER 'demo_user'@'localhost' PASSWORD EXPIRE;  -- Force reset on next login
-- ALTER USER 'demo_user'@'localhost' ACCOUNT LOCK;    -- Temporarily lock account
-- ALTER USER 'demo_user'@'localhost' ACCOUNT UNLOCK;  -- Unlock

-- [VARIATION 4] RENAME USER
-- RENAME USER 'demo_user2'@'%' TO 'demo_user_renamed'@'localhost';

-- [VARIATION 5] DROP USER (Remove user completely)
-- DROP USER IF EXISTS 'demo_user2'@'%';
-- DROP USER IF EXISTS 'demo_user_renamed'@'localhost';


-- ===================================================================
-- SECTION 9: DCL - GRANTING PRIVILEGES (ALL PERMUTATIONS)
-- ===================================================================

-- Ensure the user exists (create it safely)
CREATE USER IF NOT EXISTS 'app_user'@'localhost' IDENTIFIED BY 'AppPass123!';

-- [VARIATION 1] Grant ALL PRIVILEGES on a specific database
GRANT ALL PRIVILEGES ON demo_tcl_dcl.* TO 'app_user'@'localhost';

-- [VARIATION 2] Grant specific privileges (SELECT, INSERT, UPDATE) on all tables
GRANT SELECT, INSERT, UPDATE ON demo_tcl_dcl.* TO 'app_user'@'localhost';

-- [VARIATION 3] Grant DELETE privilege on a specific table
GRANT DELETE ON demo_tcl_dcl.accounts TO 'app_user'@'localhost';

-- [VARIATION 4] Grant column-level privileges (only allow UPDATE on 'balance')
GRANT UPDATE (balance) ON demo_tcl_dcl.accounts TO 'app_user'@'localhost';

-- [VARIATION 5] Grant SELECT on specific columns
GRANT SELECT (acc_id, acc_holder) ON demo_tcl_dcl.accounts TO 'app_user'@'localhost';

-- [VARIATION 6] Grant EXECUTE privilege on stored procedures (if you had one)
-- GRANT EXECUTE ON PROCEDURE demo_tcl_dcl.my_procedure TO 'app_user'@'localhost';

-- [VARIATION 7] Grant WITH GRANT OPTION (allows user to grant privileges to others)
GRANT SELECT ON demo_tcl_dcl.* TO 'app_user'@'localhost' WITH GRANT OPTION;

-- [VARIATION 8] Grant USAGE (No actual privileges, just allows connection)
GRANT USAGE ON *.* TO 'app_user'@'localhost';

-- [VARIATION 9] Grant privileges on all databases (global level)
-- GRANT CREATE, DROP, ALTER ON *.* TO 'app_user'@'localhost';


-- ===================================================================
-- SECTION 10: DCL - REVOKING PRIVILEGES (ALL VARIATIONS)
-- ===================================================================

-- [VARIATION 1] Revoke a specific privilege
REVOKE DELETE ON demo_tcl_dcl.accounts FROM 'app_user'@'localhost';

-- [VARIATION 2] Revoke multiple privileges at once
REVOKE INSERT, UPDATE ON demo_tcl_dcl.* FROM 'app_user'@'localhost';

-- [VARIATION 3] Revoke column-level privilege
REVOKE UPDATE (balance) ON demo_tcl_dcl.accounts FROM 'app_user'@'localhost';

-- [VARIATION 4] Revoke GRANT OPTION (keep the base privileges)
REVOKE GRANT OPTION ON demo_tcl_dcl.* FROM 'app_user'@'localhost';

-- [VARIATION 5] Revoke ALL PRIVILEGES (removes everything on that scope)
REVOKE ALL PRIVILEGES ON demo_tcl_dcl.* FROM 'app_user'@'localhost';

-- [VARIATION 6] Revoke ALL (global) - removes all privileges globally
-- REVOKE ALL PRIVILEGES, GRANT OPTION FROM 'app_user'@'localhost';


-- ===================================================================
-- SECTION 11: DCL - VIEWING PRIVILEGES
-- ===================================================================

-- [VARIATION 1] Show grants for the current user
SHOW GRANTS;

-- [VARIATION 2] Show grants for a specific user
SHOW GRANTS FOR 'app_user'@'localhost';

-- [VARIATION 3] Show grants using the old style (without FOR)
-- SHOW GRANTS;  -- (same as current user)


-- ===================================================================
-- SECTION 12: DCL - ROLES (MySQL 8.0+ Feature)
-- ===================================================================

-- [VARIATION 1] Create a new role
CREATE ROLE IF NOT EXISTS 'app_developer_role', 'app_readonly_role';

-- [VARIATION 2] Grant privileges to a role
GRANT SELECT, INSERT, UPDATE, DELETE ON demo_tcl_dcl.* TO 'app_developer_role';
GRANT SELECT ON demo_tcl_dcl.* TO 'app_readonly_role';

-- [VARIATION 3] Grant a role to a user
GRANT 'app_developer_role' TO 'app_user'@'localhost';

-- [VARIATION 4] Set default role for a user (auto-activates on login)
SET DEFAULT ROLE 'app_developer_role' TO 'app_user'@'localhost';

-- [VARIATION 5] Activate a role for the current session (if not default)
SET ROLE 'app_readonly_role';  -- Switch to readonly for this session

-- [VARIATION 6] Check the currently active role
SELECT CURRENT_ROLE();

-- [VARIATION 7] Revoke a role from a user
REVOKE 'app_developer_role' FROM 'app_user'@'localhost';

-- [VARIATION 8] Drop a role
DROP ROLE IF EXISTS 'app_developer_role', 'app_readonly_role';

-- [VARIATION 9] Grant privileges WITH ADMIN OPTION (allows role management)
CREATE ROLE 'admin_role';
GRANT ALL ON demo_tcl_dcl.* TO 'admin_role' WITH ADMIN OPTION;
GRANT 'admin_role' TO 'app_user'@'localhost';


-- ===================================================================
-- SECTION 13: CLEANUP (Optional - Comment out if you want to keep data)
-- ===================================================================

-- Drop the test database
-- DROP DATABASE IF EXISTS demo_tcl_dcl;

-- Drop the test users and roles (Run if you are root)
-- DROP USER IF EXISTS 'app_user'@'localhost';
-- DROP USER IF EXISTS 'demo_user'@'localhost';
-- DROP ROLE IF EXISTS 'admin_role';

-- ===================================================================
--                           SUMMARY OF COVERAGE
-- TCL:    START/BEGIN, COMMIT, ROLLBACK, SAVEPOINT, RELEASE SAVEPOINT,
--         SET AUTOCOMMIT, 4 ISOLATION LEVELS, FOR UPDATE, LOCK IN SHARE MODE,
--         LOCK/UNLOCK TABLES.
-- DCL:    CREATE/ALTER/RENAME/DROP USER, GRANT (ALL, specific, column-level,
--         WITH GRANT OPTION), REVOKE (specific, all, GRANT OPTION), 
--         SHOW GRANTS, CREATE/DROP/GRANT/REVOKE/SET DEFAULT ROLE.
-- ===================================================================