-- Create user with password:
CREATE USER 'app_user'@'192.168.1.%' 
IDENTIFIED BY 'StrongP@ssw0rd!';

Create user 'kunal'@'%'
identified by 'kunal@123';

GRANT SELECT
ON da_carburator_project.*
TO 'kunal'@'%';

-- reload permission in user table
flush privileges;

-- delete user
drop user 'kunal'@'%';


-- specific machine login credential
Create user 'kunal'@'192.168.1.107'
identified by 'kunal@123';

-- select permission to user
GRANT SELECT
ON da_carburator_project.*
TO 'kunal'@'192.168.1.107';

drop user 'kunal'@'192.168.1.107';
flush privileges;

-- password change
alter user 'kunal'@'%'
identified by 'kunal@456';


-- permission revoke
REVOKE select ON da_carburator_project.* FROM 'kunal'@'%';

-- multiple permission to user
GRANT create,select
ON da_carburator_project.*
TO 'kunal'@'%';

-- table level access
GRANT insert
ON da_carburator_project.age
TO 'kunal'@'%';

drop user 'kunal'@'%';
GRANT SELECT
ON da_carburator_project.age
TO 'kunal'@'%';
flush privileges;

-- column level access
GRANT SELECT (facilityid, suplierid)
ON da_carburator_project.contract
TO 'kunal'@'%';

select facilityid,suplierid from contract;

-- check permission status
SHOW GRANTS FOR 'kunal'@'%';
SHOW GRANTS FOR 'root'@'localhost';
-- user records
SELECT * FROM mysql.user;

create database test_grant_option;
grant all privileges on test_grant_option.* 
to 'kunal'@'%' with grant option;

create user 'sakshi'@'192.168.1.41' identified by 'sakshi@123';
flush privileges;

-- role based permission
create role data_analyst;

Grant all privileges on test_grant_option.* to data_analyst;

create user 'muskan'@'%' identified by 'muskan@456';
-- template
GRANT analyst_role TO 'u1','u2','u3';
grant data_analyst to 'muskan';
SHOW GRANTS FOR 'muskan'@'%';