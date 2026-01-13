use da_carburator_project;
show tables;
-- * is shortcut for all columns
select * from facility;

-- perticular column selection
select facilityid,country,city from facility;

-- 1+2=3
select 1+2;

-- current time
select now();
select curdate();
select curtime();
select database();
select 5-4;
select 5*4;
select 5>4;
select 4>5;

select -5 and 1;

select * from facility;

-- aggrigate function(sum,avg,min,max,count)
select max(employee_count) from facility;
select min(employee_count) from facility;
select sum(employee_count) from facility;
select avg(employee_count) from facility;
select count(employee_count) from facility;

-- when you use select query to display normal column 
# and aggregate function it will produce error because of data unbalance;

/* adfaschsc
hasfdkasd
fdjgasd*/ -- multiline comment
-- using aggregate function with normal column require grouping
select manufacturerid,count(*) from facility;

select manufacturerid,count(*) from facility
group by manufacturerid;

select max(employee_count),min(employee_count),
avg(employee_count),sum(employee_count),
count(employee_count) from facility;

select manufacturerid,max(employee_count),min(employee_count),
avg(employee_count),sum(employee_count),
count(employee_count) from facility;

select country,facilitytype,count(*) as records
from facility group by country,facilitytype;

select country,facilitytype,count(*) as records
from facility where count(*)>5 group by country,facilitytype;

select country,facilitytype,count(*) as records
from facility  group by country,facilitytype having count(*)>5;

-- default order is asending,asc
select country,facilitytype,count(*) as records
from facility  group by country,facilitytype 
order by count(*);

-- decending desc
select country,facilitytype,count(*) as records
from facility  group by country,facilitytype 
order by count(*) desc,facilitytype desc;
