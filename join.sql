CREATE DATABASE practice_db;
USE practice_db;

CREATE TABLE customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,-- cluster index--arrangement of table records
    `name` VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE
);

INSERT INTO customers (`name`, email) VALUES
('Rahul Sharma', 'rahul@gmail.com'),
('Anita Verma', 'anita@gmail.com'),
('Amit Singh', 'amit@gmail.com');
select * from customers;
INSERT INTO customers  VALUES
(44,'Rahul Sharma', 'rahultat@gmail.com');
INSERT INTO customers(`name`, email)  VALUES
('Rahul Sharma', 'rahultate@gmail.com');

drop table orders;

CREATE TABLE orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    order_date DATE NOT NULL,
    amount DECIMAL(10,2),
    customer_id INT,
    CONSTRAINT fk_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        on update cascade
        on delete cascade
);

INSERT INTO orders (order_date, amount, customer_id) VALUES
('2025-01-10', 2500.00, 1),
('2025-01-11', 1800.50, 1),
('2025-01-12', 3200.00, 2),
('2025-01-13', 1500.00, 3);
select * from customers;
select * from orders;
INSERT INTO orders (order_date, amount, customer_id) VALUES
('2025-01-10', 2500.00, 4);

delete from customers
where customer_id=1;

set sql_safe_updates=0;
update customers
set customer_id=50
where `name` ='Anita Verma';

select * from customers;
select * from orders;

desc customers;
desc orders;

select * from customers as c inner join orders as o 
on c.customer_id=o.customer_id;

select * from customers as c left join orders as o 
on c.customer_id=o.customer_id;

select * from customers as c right join orders as o 
on c.customer_id=o.customer_id;

select c.customer_id,c.name,c.email,o.order_id,o.order_date,o.amount from customers as c left join orders as o 
on c.customer_id=o.customer_id;

select * from customers cross join orders;
select * from customers natural join orders;

select * from mysql.user;

drop user 'data_analyst'