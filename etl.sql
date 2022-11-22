

drop database if exists `pos`;
create database `pos`;
use `pos`;

drop table if exists `status`;
create table `status`
(
`status` tinyint, 
description varchar(12), 
primary key(`status`)
);

drop table if exists `tmp_status`;
create table `tmp_status`
(
`status` tinyint, 
description varchar(128)
);


--Temp customer
drop table if exists `tmp_customer`;
create table tmp_customer(
ID int, 
FN varchar(128),
LN varchar(128),
CT varchar(128),
ST varchar(128),
ZP decimal(5,0) zerofill,
S1 varchar(128),
S2 varchar(128),
EM varchar(128),
BD varchar(128)
);

--Load in Temp Customer
Load data local infile 'customers.csv'
Into table tmp_customer
Fields Terminated by ','
Enclosed by '"'
Lines terminated by '\n'
Ignore 1 lines
(ID, FN, LN, CT, ST, ZP, S1, S2, EM, BD);

--City
drop table if exists `city`;
create table `city`
(
zip decimal(5) unsigned zerofill,    
city varchar(32),
state varchar(4),
primary key(zip)
);

--Temp City
-- drop table if exists `tmp_city`;
-- create table `tmp_city`
-- (
-- ZP decimal(5) unsigned zerofill,    
-- CT varchar(32),
-- ST varchar(4)
-- );

-- Load data local infile 'customers.csv'
-- Into table tmp_city
-- Fields Terminated by ','
-- Enclosed by '"'
-- Lines terminated by '\n'
-- Ignore 1 rows
-- (ZP, CT, ST);

--Insert in City
Insert into city(zip, city, state)
Select distinct zp, ct, st from tmp_customer group by zp;


--Product 
drop table if exists `product`;
create table `product`
(
ID int,
`name` varchar(128),
currentPrice decimal(6,2),
qtyOnHand int,
primary key(ID)
);

--Temp Product
drop table if exists `tmp_product`;
create table `tmp_product`
(
ID int,
`name` varchar(128),
currentPrice varchar(128),
qtyOnHand varchar(128)
);

--load in Temp Product
Load data local infile 'products.csv'
Into table `tmp_product`
Fields Terminated by ','
Enclosed by '"'
Lines terminated by '\n'
Ignore 1 lines
(ID, name, currentPrice, qtyOnHand);

--Insert in product
Insert into product(ID, name, currentPrice, qtyOnHand)
Select ID, name, cast(replace(replace(currentPrice, '$', ''), ',', '') as decimal(6,2)), qtyOnHand from tmp_product;


--Customer
drop table if exists `customer`;
create table customer(
ID int, 
firstName varchar(64),
lastName varchar(32),
email varchar(128),
address1 varchar(128),
address2 varchar(128),
phone varchar(32),
birthDate date,
zip decimal(5,0) zerofill,
primary key(ID),
foreign key (zip) references city(zip)
);

--Insert in Customer
Insert into customer(ID, firstName, lastName, email, address1, address2, birthDate, zip)
Select ID, FN, LN, EM, S1, S2, str_to_date(BD, '%m/%d/%Y'), ZP from tmp_customer; 
Update customer set birthDate = null where birthDate = '0000-00-00';
Update customer set address2 = null where address2 = '';


--Order
drop table if exists `order`;
create table `order`
(
ID int, 
datePlaced date,
dateShipped date,
`status` tinyint,
customerID int,
primary key(ID),
foreign key(`status`) references `status`(`status`), 
foreign key(customerID) references customer(ID)   
);

--Temp Order
drop table if exists `tmp_order`;
create table `tmp_order`
(
`OID` int, 
`CID` int
);

--load in Temp Order
Load data local infile 'orders.csv'
Into table tmp_order
Fields Terminated by ','
Enclosed by '"'
Lines terminated by '\n'
Ignore 1 lines
(`OID`, `CID`);

--Insert in Order
Insert into `order` (ID, customerID)
select `OID`, `CID` From tmp_order; 


--OrderLine
drop table if exists `orderLine`;
create table orderLine
(
orderID int,
productID int,
quantity int,
primary key(orderID, productID),
foreign key(orderID) references `order`(ID),
foreign key(productID) references `product`(ID)
);

--Temp Orderline
drop table if exists `tmp_orderLine`;
create table tmp_orderLine
(
`OID` int,
`PID` int
);

--Load in Temp OrderLine
Load data local infile 'orderlines.csv'
Into table tmp_orderLine
Fields Terminated by ','
Enclosed by '"'
Lines terminated by '\n'
Ignore 1 lines
(`OID`, `PID`);

--Insert into orderLine
INSERT INTO orderLine (orderID, productID, quantity)
select `OID`, `PID`, count(*) from tmp_orderLine
group by `OID`,`PID`;


--Drop temp tables
drop table if exists `tmp_order`;
drop table if exists `tmp_customer`;
drop table if exists `tmp_orderLine`;
drop table if exists `tmp_product`;
drop table if exists `tmp_status`;