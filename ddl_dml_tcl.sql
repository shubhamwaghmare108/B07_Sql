-- create delete database
drop database if exists b07;
create database b07;

-- database select
use b07;

-- table creation
create table student(
stuid int,
stuname varchar(10),
mobno varchar(10));

-- list of tables
show tables;

-- table information
desc student;

-- read data
select * from student;

-- delete table
drop table student;
show tables;

-- add column
alter table student
add column city varchar(20);

alter table student
add column city varchar(20) after stuname;

alter table student
add column city varchar(20) first;


select * from student;

-- delete column
alter table student
drop column city;


-- change column position
alter table student
modify column city varchar(10) after mobno;

-- change data type
alter table student
modify column stuname char(50);
desc student;

-- change column name
alter table student
rename column stuname to `name`;

-- change table name
rename table student to student_record;
select * from student;
select * from student_record;

rename table student_record to student;

select * from student;
alter table student
drop column city;
insert into student values
(1,"shubham","8983471527"),
(1,"shubham","8983471527"),
(1,"shubham","8983471527"),
(1,"shubham","8983471527"),
(1,"shubham","8983471527");

select * from student;
-- delete all records
truncate table student;

set sql_safe_updates=0;
desc student;

insert into student(`name`,stuid,mobno)
values("raj",2,"99999999"),
("suraj",3,"8945654626");

insert into student
values("raj",2,"99999999"),
("suraj",3,"8945654626");
desc student;
insert into student values
(1,"shubham","8983471527");

select * from student;

start transaction;
update student
set `name`='Raj'
where stuid=1;
rollback;

start transaction;
update student
set `name`='Raj';
rollback;
select * from student;
rollback;


start transaction;
delete from student;
rollback;
select * from student;
drop table student;
show tables;
show databases;
drop database b07;

start transaction;
select * from student;
delete from student
where stuid=2;
savepoint s1;
update student
set name='Niraj'
where stuid=3;
savepoint s2;
delete from student
where stuid=1;
select * from student;
rollback;

select * from student;

start transaction;
select * from student;
delete from student
where stuid=2;
savepoint s1;
update student
set name='Niraj'
where stuid=3;
savepoint s2;
delete from student
where stuid=1;
select * from student;
rollback to s2;
select * from student;
rollback to s1;
select * from student;

rollback to s2;
commit;
