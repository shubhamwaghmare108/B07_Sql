use da_carburator_project;
show tables;
-- * is shortcut for all columns
select * from facility;

-- particular column selection
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

select * from facility;
-- limit records for result set
select * from facility limit 5;

-- offset changes reference point
select * from facility limit 5 offset 5;-- pagination
select * from facility limit 5 offset 10;

-- distinct use for displaying each value once only.
select distinct(facilitytype) from facility;
select distinct(country) from facility;
select count(distinct(country)) from facility;
select distinct country,city from facility;
select distinct facilitytype,country from facility;

select facilitytype,country,count(*) from facility
group by facilitytype,country;

-- in ,between,like
select * from facility;
select * from facility
where country in ('france','india');

select * from facility
where country='france' or country='india';

select * from facility
where employee_count between 3500 and 3600;

select * from facility 
where employee_count>=3500 and employee_count<=3600;

select * from facility
where ManufacturerId between 1 and 10;-- included

show tables;
select * from production;

select * from production
where `date` between '2016-01-01' and '2016-02-01';-- included

select * from facility;
select * from facility
where country between 'a' and 'j';-- text last is not included

-- % any character any times
select * from facility where country like 'c%';
select * from facility where country like '%c%';
select * from facility where country like '%a';

-- _ fix character ,length
select * from facility where country like '_____';-- five character name
select * from facility where country like 'c____';
select * from facility where country like 'in____%';

-- wild card character %,_
