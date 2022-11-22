use `pos`;

--1) 
    create or replace view v_CustomerNames as select lastName LN, firstName FN from customer order by lastName, firstName;

--2)
    create or replace view v_Customers as select cust.ID customer_number, cust.firstName first_name, cust.lastName last_name, cust.address1 street1, cust.address2 street2, city.city, city.state, cust.zip zip_code, cust.email from customer cust left join city city on cust.zip = city.zip;

--3) 
    create or replace view v_ProductBuyers as 
    select prod.ID productID, prod.name productName, group_concat(distinct cust.ID , ' ' , cust.firstName , ' ' , cust.lastName order by cust.ID) as customers from
    (product prod left join orderLine on prod.ID = orderLine.productID
    left join `order` on orderLine.orderID = `order`.ID
    left join customer cust on cust.ID = order.customerID) 
    group by prod.ID, prod.name;
    --order by cust.ID;

--4) 
    create or replace view v_CustomerPurchases as

    select cust.ID, cust.firstName, cust.lastName, group_concat(distinct prod.ID, ' ', prod.name order by prod.ID separator '|') as products from 
    (
    customer cust left join `order` on cust.ID = `order`.customerID 
    left join orderLine on `order`.ID = orderLine.orderID
    left join product prod on orderLine.productID = prod.ID
    )
    group by cust.ID, cust.firstName;
    --order by prod.ID;


--5) 
    drop table if exists mv_ProductBuyers;
    create table mv_ProductBuyers as
    select prod.ID productID, prod.name productName, group_concat(distinct cust.ID , ' ' , cust.firstName , ' ' , cust.lastName order by cust.ID) as customers from 
   (product prod left join orderLine on prod.ID = orderLine.productID
   left join `order` on orderLine.orderID = `order`.ID
   left join customer cust on cust.ID = order.customerID) 
   group by prod.ID;
   --order by cust.ID;

   drop table if exists mv_CustomerPurchases;
   create table mv_CustomerPurchases as
   select cust.ID, cust.firstName, cust.lastName, group_concat(distinct prod.ID, ' ', prod.name order by prod.ID separator '|') products from 
   (
    customer cust left join `order` on cust.ID = `order`.customerID 
    left join orderLine on `order`.ID = orderLine.orderID
    left join product prod on orderLine.productID = prod.ID
   )
   group by cust.ID;
   --order by prod.ID;

--6) 
    drop index if exists idx_CustomerEmail on customer;
    create index idx_CustomerEmail on customer (email);

--7) 
   drop index if exists idx_ProductName on product;
   create index idx_ProductName on product (`name`);


